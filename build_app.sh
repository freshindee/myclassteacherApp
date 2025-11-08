#!/bin/bash

# MyClassTeacher App Build Script
# This script helps build signed app bundles and APKs

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Flutter is installed
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    
    # Check if we're in the right directory
    if [ ! -f "pubspec.yaml" ]; then
        print_error "This script must be run from the Flutter project root directory"
        exit 1
    fi
    
    # Check Flutter doctor
    print_status "Running Flutter doctor..."
    flutter doctor
    
    print_success "Prerequisites check completed"
}

# Function to configure keystore
configure_keystore() {
    print_status "Configuring keystore..."
    
    # Check if gradle.properties exists
    if [ ! -f "android/gradle.properties" ]; then
        print_error "android/gradle.properties not found"
        exit 1
    fi
    
    # Check if keystore configuration is set
    if grep -q "MYAPP_UPLOAD_STORE_PASSWORD=your_store_password" android/gradle.properties; then
        print_warning "Default keystore passwords detected in android/gradle.properties"
        echo "Please edit android/gradle.properties and set your actual keystore passwords:"
        echo "  MYAPP_UPLOAD_STORE_PASSWORD=your_actual_password"
        echo "  MYAPP_UPLOAD_KEY_PASSWORD=your_actual_password"
        echo ""
        read -p "Press Enter after updating the passwords..."
    fi
    
    print_success "Keystore configuration completed"
}

# Function to build app bundle
build_app_bundle() {
    print_status "Building signed app bundle..."
    
    cd android
    
    # Generate keystore if it doesn't exist
    if [ ! -f "app/myclassteacher.keystore" ]; then
        print_status "Generating keystore..."
        ./gradlew generateKeystore
    fi
    
    # Build the bundle
    ./gradlew buildSignedBundle
    
    cd ..
    
    # Check if bundle was created
    if [ -f "android/app/build/outputs/bundle/release/app-release.aab" ]; then
        print_success "App bundle built successfully!"
        print_status "Location: android/app/build/outputs/bundle/release/app-release.aab"
        
        # Show bundle size
        bundle_size=$(du -h "android/app/build/outputs/bundle/release/app-release.aab" | cut -f1)
        print_status "Bundle size: $bundle_size"
    else
        print_error "Failed to build app bundle"
        exit 1
    fi
}

# Function to build APK
build_apk() {
    print_status "Building signed APK..."
    
    cd android
    
    # Generate keystore if it doesn't exist
    if [ ! -f "app/myclassteacher.keystore" ]; then
        print_status "Generating keystore..."
        ./gradlew generateKeystore
    fi
    
    # Build the APK
    ./gradlew buildSignedApk
    
    cd ..
    
    # Check if APK was created
    if [ -f "android/app/build/outputs/apk/release/app-release.apk" ]; then
        print_success "APK built successfully!"
        print_status "Location: android/app/build/outputs/apk/release/app-release.apk"
        
        # Show APK size
        apk_size=$(du -h "android/app/build/outputs/apk/release/app-release.apk" | cut -f1)
        print_status "APK size: $apk_size"
    else
        print_error "Failed to build APK"
        exit 1
    fi
}

# Function to show help
show_help() {
    echo "MyClassTeacher App Build Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  bundle    Build signed app bundle (.aab) - recommended for Play Store"
    echo "  apk       Build signed APK (.apk)"
    echo "  both      Build both bundle and APK"
    echo "  check     Check prerequisites only"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 bundle    # Build app bundle only"
    echo "  $0 apk       # Build APK only"
    echo "  $0 both      # Build both bundle and APK"
    echo ""
}

# Main script logic
main() {
    case "${1:-help}" in
        "bundle")
            check_prerequisites
            configure_keystore
            build_app_bundle
            ;;
        "apk")
            check_prerequisites
            configure_keystore
            build_apk
            ;;
        "both")
            check_prerequisites
            configure_keystore
            build_app_bundle
            build_apk
            ;;
        "check")
            check_prerequisites
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function with all arguments
main "$@"
