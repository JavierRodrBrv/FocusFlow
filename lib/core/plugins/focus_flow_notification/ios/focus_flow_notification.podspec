#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint focus_flow_notification.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'focus_flow_notification'
  s.version          = '0.0.1'
  s.summary          = 'Custom native notification for FocusFlow.'
  s.description      = <<-DESC
A custom native notification plugin for FocusFlow to handle Pomodoro timer controls on iOS.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
