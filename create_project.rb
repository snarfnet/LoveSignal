require 'xcodeproj'

PROJECT_NAME = 'LoveSignal'
BUNDLE_ID = 'com.tokyonasu.LoveSignal'
TEAM_ID = '83VGKGSQUH'

project_path = File.expand_path("#{PROJECT_NAME}.xcodeproj", __dir__)
project = Xcodeproj::Project.new(project_path)
target = project.new_target(:application, PROJECT_NAME, :ios, '16.0')

target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = BUNDLE_ID
  config.build_settings['DEVELOPMENT_TEAM'] = TEAM_ID
  config.build_settings['SWIFT_VERSION'] = '5.9'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['INFOPLIST_FILE'] = "#{PROJECT_NAME}/Info.plist"
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  config.build_settings['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
end

main_group = project.main_group
app_group = main_group.new_group(PROJECT_NAME, PROJECT_NAME)

# Subgroups
app_dir = app_group.new_group('App', 'App')
models_dir = app_group.new_group('Models', 'Models')
viewmodels_dir = app_group.new_group('ViewModels', 'ViewModels')
views_dir = app_group.new_group('Views', 'Views')
components_dir = views_dir.new_group('Components', 'Components')
match_dir = views_dir.new_group('Match', 'Match')
planner_dir = views_dir.new_group('Planner', 'Planner')
psychology_dir = views_dir.new_group('Psychology', 'Psychology')
settings_dir = views_dir.new_group('Settings', 'Settings')
today_dir = views_dir.new_group('Today', 'Today')
utils_dir = app_group.new_group('Utils', 'Utils')
data_dir = app_group.new_group('Data', 'Data')

def add_sources(group, target, names)
  names.each do |name|
    ref = group.new_file(name)
    target.add_file_references([ref])
  end
end

def add_resources(group, target, names)
  names.each do |name|
    ref = group.new_file(name)
    target.add_resources([ref])
  end
end

add_sources(app_dir, target, ['LoveSignalApp.swift'])

add_sources(models_dir, target, [
  'DatePlan.swift',
  'MatchQuestion.swift',
  'PsychologyTechnique.swift',
  'Tip.swift'
])

add_sources(viewmodels_dir, target, [
  'MatchViewModel.swift',
  'PlannerViewModel.swift',
  'PsychologyViewModel.swift',
  'TodayViewModel.swift'
])

add_sources(views_dir, target, ['MainTabView.swift'])
add_sources(components_dir, target, ['AppComponents.swift'])
add_sources(match_dir, target, ['MatchResultView.swift', 'MatchView.swift'])
add_sources(planner_dir, target, ['PlanDetailView.swift', 'PlannerView.swift'])
add_sources(psychology_dir, target, ['PsychologyView.swift', 'TechniqueDetailView.swift'])
add_sources(settings_dir, target, ['SettingsView.swift'])
add_sources(today_dir, target, ['TodayView.swift'])

add_sources(utils_dir, target, ['Constants.swift', 'Extensions.swift'])

add_resources(data_dir, target, [
  'daily_tips.json',
  'date_plans.json',
  'match_questions.json',
  'psychology_data.json'
])

assets_ref = app_group.new_file('Assets.xcassets')
target.add_resources([assets_ref])
privacy_ref = app_group.new_file('PrivacyInfo.xcprivacy')
target.add_resources([privacy_ref])
app_group.new_file('Info.plist')

project.save
puts "Created #{project_path}"
