# Generated by hyrax:models:install
class FileSet < ActiveFedora::Base
  include ::RightsOverrideBehavior
  include ::Hyrax::FileSetBehavior

  def visibility=(value)
    case value
    when VisibilityService::VISIBILITY_TEXT_VALUE_SUPPRESS_DISCOVERY,
           VisibilityService::VISIBILITY_TEXT_VALUE_CULTURALLY_SENSITIVE
      self.rights_override = VisibilityService.rights_override_value(value)
      value = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    when VisibilityService::VISIBILITY_TEXT_VALUE_METADATA_ONLY
      self.rights_override = VisibilityService.rights_override_value(value)
      value = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    else
      self.rights_override = nil
    end
    super
  end
end
