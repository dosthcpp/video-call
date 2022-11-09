# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

source 'https://github.com/CocoaPods/Specs.git'
target 'carewell' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'FSCalendar'
  pod 'MultipartForm'
  pod 'GoogleWebRTC'
  pod 'CameraManager'
  pod 'ReachabilitySwift'
  pod 'FloatingPanel'

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |build_configuration|
        build_configuration.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64 i386'
      end
    end
  end

  # Pods for carewell
end
