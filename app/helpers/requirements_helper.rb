# frozen_string_literal: true

module RequirementsHelper
  # Builds an HTML string stating if the user has satisfied all requirements for
  # the given model
  #
  # @param current_user [User] The user to check requirements against
  # @param em [EquipmentModel] The equipment model to check requirements against
  #
  # @return [String] An html-safe string that displays the unsatisfied
  #   requirements along with admin contact information
  def list_requirement_admins(current_user, em)
    met_reqs = (em.requirements & current_user.requirements)
    outstanding_reqs = em.requirements - met_reqs
    req_status = [outstanding_msg(outstanding_reqs)]
    if met_reqs.empty?
      req_status.append 'This model requires proper training before it can be '\
                        'reserved.'
    else
      req_status.append 'You have already met the requirements to check out '\
                        "this model set by #{admin_names(met_reqs)}. "\
                        'However, this model requires additional training '\
                        'before it can be reserved.'
    end
    # this is currently returning all names, then all email addresses, in one
    # sentence
    resp = outstanding_reqs.count > 1 ? ' respectively' : ''
    req_status.append "Please contact #{admin_names(outstanding_reqs)}#{resp} "\
                      "at #{admin_contacts(outstanding_reqs)} about becoming "\
                      'certified.'
    safe_join(req_status, ' ')
  end

  private

  # this method MUST return a sanitized string
  def admin_names(reqs)
    sanitize reqs.map(&:contact_name).to_sentence
  end

  # this method MUST return a sanitized string
  def admin_contacts(reqs)
    sanitize reqs.map(&:contact_info).to_sentence
  end

  # this method MUST return a sanitized string
  def outstanding_msg(reqs)
    safe_join([raw('<ul>'),
               *reqs.map { |r| raw("<li>#{sanitize r.description}</li>") },
               raw('</ul>')])
  end
end
