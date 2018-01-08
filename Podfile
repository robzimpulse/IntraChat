# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'IntraChat' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for IntraChat
  
  pod 'MessageKit'
  pod 'ObjectMapper'
  pod 'PusherChatkit'
  pod 'AlamofireImage'
  pod 'IQKeyboardManager'
  pod 'EZSwiftExtensions'
  
  pod 'RxSwift'
  pod 'RxCocoa'
  
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Storage'
  pod 'Firebase/Database'
end

post_install do |installer|
    myExcludedTargets = ['MessageKit','ILLoginKit']
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
