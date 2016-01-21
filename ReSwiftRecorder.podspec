Pod::Spec.new do |s|
  s.name             = "ReSwiftRecorder"
  s.version          = "0.2.3"
  s.summary          = "Time Travel and Hot Reloading for ReSwift"
  s.description      = <<-DESC
                          A recording store for ReSwift. Enables hot-reloading and time travel for ReSwift apps.
                          Still in experimental stage!
                        DESC
  s.homepage         = "https://github.com/ReSwift/ReSwift-Recorder"
  s.license          = { :type => "MIT", :file => "LICENSE.md" }
  s.author           = { "Benjamin Encz" => "me@benjamin-encz.de" }
  s.social_media_url = "http://twitter.com/benjaminencz"
  s.source           = { :git => "https://github.com/ReSwift/ReSwift-Recorder.git", :tag => s.version.to_s }
  s.ios.deployment_target     = '8.0'
  s.requires_arc = true
  s.source_files     = 'ReSwiftRecorder/**/*.swift'
  s.dependency 'ReSwift', '~> 0.2.3'
end
