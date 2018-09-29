Pod::Spec.new do |s|
  s.name         = "mapstr.l10n"
  s.version      = "0.2.6"
  s.summary      = "Mapstr localization files."
  s.description  = <<-DESC
                    languages:
                    - English.
                    - French.
                    - German.
                    - Dutch.
                    - Spanish.
                    - Italian.
                    - Portuguese (Brazilian).
                    - Danish.
                    - Swedish.
                    - Finnish.
                    - Japonese.
                   DESC
  s.homepage     = "https://git.hulab.co/mapstr/mapstr-l10n"
  s.license      = 'Trade Secret'
  s.author       = { "Mapstr team" => "hello@mapstr.com" }
  s.source       = { :git => "https://git.hulab.co/mapstr/mapstr-l10n.git", :tag => s.version.to_s }
  s.requires_arc = true

  s.platform = :ios, :osx, :tvos, :watchos
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'
  s.swift_version = '3.2'

  s.default_subspecs = 'po', 'lproj'

  s.subspec 'po' do |ss|
    ss.resources = 'po/*.po'
  end

  s.subspec 'lproj' do |ss|
    ss.resources = 'ios/*.lproj'
  end

  s.dependency 'POLocalizedString', '~> 1.1.6'

end
