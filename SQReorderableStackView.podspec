#
# Be sure to run `pod lib lint SQReorderableStackView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SQReorderableStackView'
  s.version          = '0.4.2'
  s.summary          = 'A reorderable subclass of UIStackView in Swift'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
SQReorderableStackView is a UIViewSubclass updated for Swift 4.2 that adds a long press gesture recognizer to each of its subviews. When triggered, the handler will create a snapshot of the pressed subview and transform its position in response to changes in the touches. The SQReorderableStackViewDelegate protocol can be implemented by a controller to allow finer control of which subviews can be picked up and moved, and to respond to changes to the subview order made by the user.
                       DESC

  s.homepage         = 'https://github.com/markedwardmurray/SQReorderableStackView'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'markedwardmurray' => 'markedwardmurray@gmail.com' }
  s.source           = { :git => 'https://github.com/markedwardmurray/SQReorderableStackView.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/markedwardnyc'

  s.ios.deployment_target = '9.0'

  s.source_files = 'SQReorderableStackView/Classes/**/*'
  
  # s.resource_bundles = {
  #   'SQReorderableStackView' => ['SQReorderableStackView/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
