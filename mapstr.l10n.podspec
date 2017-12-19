Pod::Spec.new do |s|
  s.name         = "mapstr.l10n"
  s.version      = "0.1.0"
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
                   DESC
  s.homepage     = "https://git.hulab.co/mapstr/mapstr-l10n"
  s.license      = 'Trade Secret'
  s.author       = { "Maxime Epain" => "maxime@mapstr.com" }
  s.source       = { :git => "https://git.hulab.co/mapstr/mapstr-l10n.git", :tag => s.version.to_s }
  s.requires_arc = true

  s.platform = :ios, :osx, :tvos, :watchos
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'

  s.default_subspecs = 'mo'

  s.subspec 'mo' do |ss|
    ss.resources = 'mo/*.mo'
  end

  s.subspec 'po' do |ss|
    ss.resources = 'po/*.po'
  end

  s.dependency 'POLocalizedString', '0.3.0'

end
