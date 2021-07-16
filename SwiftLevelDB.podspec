
Pod::Spec.new do |spec|


  spec.name         = "SwiftLevelDB"
  spec.version      = "1.0.0"
  spec.summary      = "An Swift database library built over Google's LevelDB, a fast embedded key-value store written by Google."
  spec.description  = <<-DESC
    LevelDB is a fast key-value storage library written at Google that provides an ordered mapping from string keys to string values.
                   DESC
  spec.homepage     = "https://github.com/CoderYFL/Swift-LevelDB"
  spec.license      = "MIT"
  spec.author             = { "Cherish" => "390151825@qq.com" }
  spec.platform     = :ios
  spec.ios.deployment_target = "10.0"
  spec.source       = { :git => "https://github.com/CoderYFL/Swift-LevelDB.git", :tag => "1.0.0" }
  spec.source_files  = "LevelDB/*.{h,mm,swift}"
  spec.requires_arc = true
  spec.xcconfig = { "HEADER_SEARCH_PATHS" => "${PODS_ROOT}/leveldb-library/include"}
 
end
