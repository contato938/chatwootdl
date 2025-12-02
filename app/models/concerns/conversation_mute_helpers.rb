module ConversationMuteHelpers
  extend ActiveSupport::Concern

  def mute!
    resolved!
    contact.update(blocked: true)
    create_muted_message
  end

  def unmute!
    contact.update(blocked: false)
    create_unmuted_message
  end

  def muted?
    return false if contact.nil?

    contact.blocked?
  end
end
