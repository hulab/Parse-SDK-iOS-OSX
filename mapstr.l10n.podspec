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
  s.ios.deployment_target = '8.0'

  s.resources = '*.mo'

  s.dependency 'POLocalizedString'

end
