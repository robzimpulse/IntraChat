# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'IntraChat' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for IntraChat
  
  pod 'Eureka'
  pod 'Lightbox'
  pod 'MessageKit'
  pod 'ImagePicker'
  pod 'ObjectMapper'
  pod 'PusherChatkit'
  pod 'AlamofireImage'
  pod 'IQKeyboardManager'
  pod 'EZSwiftExtensions'
  pod 'DACircularProgress'
  pod 'TOCropViewController'
  
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RxRealm'
  
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Messaging'
  pod 'Firebase/Storage'
  pod 'Firebase/Database'
end

post_install do |installer|
    myExcludedTargets = ['MessageKit','ILLoginKit','ImagePicker','Lightbox','Eureka']
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            if myExcludedTargets.include? target.name
                config.build_settings['SWIFT_VERSION'] = '4.0'
                else
                config.build_settings['SWIFT_VERSION'] = '3.0'
            end
        end
    end
end
