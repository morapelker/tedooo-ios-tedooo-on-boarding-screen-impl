#
# Be sure to run `pod lib lint TedoooOnBoardingScreenImpl.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TedoooOnBoardingScreenImpl'
  s.version          = '1.3.19'
  s.summary          = 'TedoooOnBoardingScreenImpl'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TedoooOnBoardingScreenImpl
                       DESC

  s.homepage         = 'https://github.com/morapelker/tedooo-ios-tedooo-on-boarding-screen-impl'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'morapelker' => 'morapelker@gmail.com' }
  s.source           = { :git => 'https://github.com/morapelker/tedooo-ios-tedooo-on-boarding-screen-impl.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'

  s.source_files = 'TedoooOnBoardingScreenImpl/Classes/**/*'
  s.swift_version = '5.0'
  
  s.resources = ['TedoooOnBoardingScreenImpl/Assets/*.{xcassets}']
  s.resource_bundles = {
    'TedoooOnBoardingScreenImpl' => ['TedoooOnBoardingScreenImpl/Assets/*']
  }
  
  
  s.dependency 'Swinject'
  s.dependency 'TedoooCombine'
  s.dependency 'TedoooOnBoardingApi'
  s.dependency 'TedoooOnBoardingScreen'
  s.dependency 'TedoooStyling'
  s.dependency 'TedoooCategoriesApi'
  s.dependency 'Kingfisher'
  s.dependency 'AlignedCollectionViewFlowLayout'
  s.dependency 'Dwifft'
  s.dependency 'JGProgressHUD'
  s.dependency 'TedoooFullScreenHud'
  s.dependency 'TedoooSkeletonView'
  s.dependency 'CreateShopFlowApi'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
