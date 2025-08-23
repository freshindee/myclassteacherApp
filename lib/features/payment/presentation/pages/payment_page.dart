import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/payment_bloc.dart';
import '../../../../core/utils/month_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class PaymentPage extends StatefulWidget {
  final String userId;
  final String teacherId;
  
  const PaymentPage({super.key, required this.userId, required this.teacherId});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? selectedGrade;
  String? selectedSubject;
  String? selectedMonth;
  PlatformFile? selectedFile;
  UploadTask? uploadTask;
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  double _calculatedAmount = 0.0;

  final List<String> grades = ['Grade 1','Grade 2','Grade 3','Grade 4','Grade 5','Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'];
  final List<String> subjects = ['Grade 1 to 5','Mathematics', 'Science', 'English', 'ICT', 'Tamil'];
  final List<String> months = MonthUtils.getAllMonthNames();

  @override
  void initState() {
    super.initState();
    _calculateAmount();
    // Load pay account details when the page initializes
    context.read<PaymentBloc>().add(LoadPayAccountDetails(widget.teacherId));
  }

  void _calculateAmount() {
    setState(() {
      if (selectedGrade != null) {
        final gradeNumber = int.tryParse(selectedGrade!.replaceAll(RegExp(r'[^0-9]'), ''));
        if (gradeNumber != null) {
          if (gradeNumber >= 6 && gradeNumber <= 9) {
            _calculatedAmount = 700.0;
          } else if (gradeNumber >= 10 && gradeNumber <= 11) {
            _calculatedAmount = 1000.0;
          } else if (gradeNumber >= 1 && gradeNumber <= 5) {
            _calculatedAmount = 1000.0;
          } else {
            _calculatedAmount = 0.0;
          }
        } else {
          _calculatedAmount = 0.0;
        }
      } else {
        _calculatedAmount = 0.0;
      }
    });
  }

  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
        withData: true, // Ensures we get file bytes
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Validate file size (10MB limit)
        if (file.size > 10 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File size too large. Please select a file smaller than 10MB.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        // Validate file extension
        final validExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
        if (!validExtensions.contains(file.extension?.toLowerCase())) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid file type. Please select an image (JPG, PNG) or PDF file.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        setState(() {
          selectedFile = file;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File selected: ${file.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> uploadFile() async {
    if (selectedFile == null) return null;
    
    try {
      // Validate file size (e.g., max 10MB)
      if (selectedFile!.size > 10 * 1024 * 1024) {
        throw Exception('File size too large. Maximum size is 10MB.');
      }
      
      // Create a unique file path with user ID and timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${widget.userId}_${timestamp}_${selectedFile!.name}';
      final path = 'payment_slips/${widget.userId}/$fileName';
      
      final ref = FirebaseStorage.instance.ref().child(path);
      
      // Get file bytes
      Uint8List? fileBytes = selectedFile!.bytes;
      if (fileBytes == null && selectedFile!.readStream != null) {
        final bytes = await selectedFile!.readStream!.reduce((a, b) => a + b);
        fileBytes = Uint8List.fromList(bytes);
      }
      
      if (fileBytes == null) {
        throw Exception('Could not read file data');
      }
      
      // Set metadata for better organization
      final metadata = SettableMetadata(
        contentType: selectedFile!.extension == 'pdf' 
            ? 'application/pdf' 
            : 'image/${selectedFile!.extension}',
        customMetadata: {
          'userId': widget.userId,
          'originalName': selectedFile!.name,
          'uploadedAt': DateTime.now().toIso8601String(),
          'fileSize': selectedFile!.size.toString(),
        },
      );
      
      // Upload with metadata
      uploadTask = ref.putData(fileBytes, metadata);
      
      // Listen to upload progress
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });
      uploadTask!.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        setState(() {
          _uploadProgress = progress;
        });
        print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
        // You can update UI here to show progress
      }).onDone(() {
        setState(() {
          _isUploading = false;
        });
      });
      
      // Wait for upload to complete
      final snapshot = await uploadTask!.whenComplete(() {});
      
      // Get download URL
      final url = await snapshot.ref.getDownloadURL();
      
      print('File uploaded successfully: $url');
      return url;
      
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('පන්ති ගාස්තු ගෙවීම'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('මුදල් ගෙවීමේ රිසිට්පත යොමුකිරිම සාර්ථකයි, පැය 6ක් ඇතුලත ඔබට අදාළ තොරතුරු නැරබිය හැකියි.'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
          if (state is PaymentFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment failed: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'පහත තොරතුරු තෝරන්න',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Grade Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedGrade,
                            decoration: const InputDecoration(
                              labelText: 'පන්තිය',
                              border: OutlineInputBorder(),
                            ),
                            items: grades.map((grade) {
                              return DropdownMenuItem(
                                value: grade,
                                child: Text(grade),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedGrade = value;
                                _calculateAmount();
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Subject Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedSubject,
                            decoration: const InputDecoration(
                              labelText: 'විෂය',
                              border: OutlineInputBorder(),
                            ),
                            items: subjects.map((subject) {
                              return DropdownMenuItem(
                                value: subject,
                                child: Text(subject),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedSubject = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Month Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedMonth,
                            decoration: const InputDecoration(
                              labelText: 'මාසය',
                              border: OutlineInputBorder(),
                            ),
                            items: months.map((month) {
                              return DropdownMenuItem(
                                value: month,
                                child: Text(month),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedMonth = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          // File Picker Button
                          ElevatedButton.icon(
                            onPressed: pickFile,
                            icon: const Icon(Icons.attach_file),
                            label: const Text('මුදල් තැම්පත් කල රිසිට්පත තෝරන්න'),
                          ),
                          if (selectedFile != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(selectedFile!.extension == 'pdf' ? Icons.picture_as_pdf : Icons.image),
                                const SizedBox(width: 8),
                                Expanded(child: Text(selectedFile!.name)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  
                  // Pay Button
                  ElevatedButton(
                    onPressed: (selectedGrade != null && 
                               selectedSubject != null && 
                               selectedMonth != null &&
                               selectedFile != null &&
                               state is! PaymentLoading &&
                               !_isUploading)
                        ? () async {
                            try {
                              String? slipUrl;
                              if (selectedFile != null) {
                                slipUrl = await uploadFile();
                                
                                if (slipUrl == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to upload payment slip. Please try again.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                              }
                              
                              // Extract grade number only (remove "Grade" text)
                              final gradeNumber = selectedGrade!.replaceAll(RegExp(r'[^0-9]'), '');
                              
                              print('🎬 PaymentPage: Creating payment with grade number: $gradeNumber (from: $selectedGrade)');
                              
                              // Proceed with payment
                              context.read<PaymentBloc>().add(
                                CreatePaymentRequested(
                                  userId: widget.userId,
                                  grade: gradeNumber, // Send only the grade number
                                  subject: selectedSubject!,
                                  month: selectedMonth!,
                                  year: DateTime.now().year,
                                  amount: _calculatedAmount,
                                  slipUrl: slipUrl,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isUploading
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(color: Colors.white),
                              const SizedBox(height: 8),
                              Text(
                                'Uploading: ${(_uploadProgress * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ],
                          )
                        : (state is PaymentLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'ඔබගේ ගෙවීම තහවුරු කරන්න : Rs. $_calculatedAmount',
                                style: const TextStyle(fontSize: 12),
                              )),
                  ),


                    // Payment Summary Card
                  if (selectedGrade != null && selectedSubject != null && selectedMonth != null)
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'මුදල් ගෙවීමේ රිසිට්පත යොමුකිරිම',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text('පන්තිය : $selectedGrade'),
                            Text('විෂය : $selectedSubject'),
                            Text('මාසය : $selectedMonth ${DateTime.now().year}'),
                            const SizedBox(height: 8),
                            Text(
                              'මුදල : Rs. $_calculatedAmount',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                           

                  // Add spacing before the image
                  const SizedBox(height: 32),
                  
                  // Display the dynamic account image from database
                  BlocBuilder<PaymentBloc, PaymentState>(
                    builder: (context, state) {
                      if (state is PayAccountDetailsLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (state is PayAccountDetailsLoaded) {
                        return Center(
                          child: Image.network(
                            state.sliderImageUrl,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                                    SizedBox(height: 16),
                                    Text(
                                      'Failed to load account image',
                                      style: TextStyle(fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      } else if (state is PayAccountDetailsError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                state.message,
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<PaymentBloc>().add(LoadPayAccountDetails(widget.teacherId));
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Show a placeholder or loading state
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Loading account details...',
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 