require File.dirname(__FILE__) + '/support/setup'

# A background job to update all child models with the correct access level
# of the parent document, and update all assets on S3.
class UpdateAccess < CloudCrowd::Action

  def process
    begin
      ActiveRecord::Base.establish_connection
      access   = options['access']
      document = Document.find(input)
      attrs    = { :access => access, :document_id => document.id }
      Page.update_all(attrs)
      Entity.update_all(attrs)
      EntityDate.update_all(attrs)
      DC::Store::AssetStore.new.set_access(document, access)
      document.update_attributes(:access => access)
    rescue Exception => e
      LifecycleMailer.exception_notification(e,options).deliver
      document.update_attributes(:access => DC::Access::ERROR) if document
      raise e
    end
    true
  end

end
