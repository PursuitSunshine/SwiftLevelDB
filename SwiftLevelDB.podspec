Pod::Spec.new do |spec|

  spec.name         = "SwiftLevelDB"
  spec.version      = "1.0.0"
  spec.summary      = "A short description of SwiftLevelDB."
  spec.description  = <<-DESC
                       Swift LevelDB database 
                   DESC
  spec.homepage     = "https://github.com/CoderYFL/LevelDB-Swift"
  spec.ios.deployment_target = "10.0"
  spec.source       = { :git => "https://github.com/CoderYFL/SwiftLevelDB.git", :tag => "1.1.0" }
  spec.author       = { 'Cherish' => 'pursuitsunshine@gmail.com' }
  spec.source_files  =  "SwiftLevelDB/src/*.{swift,h,cpp,hpp}"
  spec.requires_arc = true
  spec.license      = "MIT"
  spec.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/leveldb-library/include" }
  spec.public_header_files = "SwiftLevelDB/src/SwiftLevelDB.h", "SwiftLevelDB/src/Wrapper.hpp"
  spec.module_name = 'SwiftLevelDB'
  spec.dependency "leveldb-library", "~> 1.22.1"
end
