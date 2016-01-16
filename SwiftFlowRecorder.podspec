Pod::Spec.new do |s|
  s.name             = "SwiftFlowRecorder"
  s.version          = "0.2.2"
  s.summary          = "Time Travel and Hot Reloading for Swift Flow"
  s.description      = <<-DESC
                          A recording store for Swift Flow. Enables hot-reloading and time travel for Swift Flow apps.
                          Still in experimental stage!
                        DESC
  s.homepage         = "https://github.com/Swift-Flow/Swift-Flow-Recorder"
  s.license          = { :type => "MIT", :file => "LICENSE.md" }
  s.author           = { "Benjamin Encz" => "me@benjamin-encz.de" }
  s.social_media_url = "http://twitter.com/benjaminencz"
  s.source           = { :git => "https://github.com/Swift-Flow/Swift-Flow-Recorder.git", :tag => s.version.to_s }
  s.ios.deployment_target     = '8.0'
  s.requires_arc = true
  s.source_files     = 'SwiftFlowRecorder/**/*.swift'
  s.dependency 'SwiftFlow', '~> 0.2.2'
end
