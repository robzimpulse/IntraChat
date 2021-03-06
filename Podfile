# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'IntraChat' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  
  # Pods for IntraChat
  pod 'Hero'
  pod 'Eureka'
  pod 'Gallery'
  pod 'Lightbox'
  pod 'MessageKit'
  pod 'FileBrowser'
  pod 'ObjectMapper'
  pod 'PusherChatkit'
  pod 'LocationPicker'
  pod 'AlamofireImage'
  pod 'LocationViewer'
  pod 'IQKeyboardManager'
  pod 'EZSwiftExtensions'
  pod 'RPCircularProgress'
  pod 'TOCropViewController'
  
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RxRealm'
  pod 'RxDataSources'
  
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Messaging'
  pod 'Firebase/Storage'
  pod 'Firebase/Database'
  
  pod 'ViewRow', :git => 'https://github.com/EurekaCommunity/ViewRow'
end

post_install do |installer|
  myExcludedTargets = ['MessageKit','ILLoginKit','Gallery','Lightbox','Eureka']
  installer.pods_project.targets.each do |target|
    
    if target.name == 'RxSwift'
      target.build_configurations.each do |config|
        if config.name == 'Debug'
          config.build_settings['OTHER_SWIFT_FLAGS'] ||= ['-D', 'TRACE_RESOURCES']
        end
      end
    end
    
    target.build_configurations.each do |config|
      if myExcludedTargets.include? target.name
        config.build_settings['SWIFT_VERSION'] = '4.0'
        else
        config.build_settings['SWIFT_VERSION'] = '3.0'
      end
    end
    
  end
end

