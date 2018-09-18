# Uncomment the next line to define a global platform for your project
# platform :ios, '11.0'

target 'OASIS1' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for OASIS1

pod 'Firebase/Core'
pod 'Firebase/Auth'
pod 'Firebase/Firestore'
pod 'Firebase/Messaging'
pod 'Firebase/Storage'
pod 'Firebase/Database'

pod 'Mapbox-iOS-SDK'

pod 'NMessenger', :git => 'https://github.com/mbalex99/NMessenger', :branch => 'swift4'

pod 'ChameleonFramework'

pod 'CHIPageControl/Aleppo'

pod 'ReachabilitySwift'

pod 'Sparrow/Modules/RequestPermission', :git => 'https://github.com/IvanVorobei/Sparrow.git'

pod "ILLoginKit"

pod 'FirebaseUI/Storage'

pod 'YPImagePicker'

end


# Workaround for Cocoapods issue #7606
post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        config.build_settings.delete('CODE_SIGNING_ALLOWED')
        config.build_settings.delete('CODE_SIGNING_REQUIRED')
    end
end