# frozen_string_literal: true

File.open("/tmp/rtf_init_ran.txt", "a") { |f| f.puts(Time.now.to_s) }

Redmine::Plugin.register :redmine_remaining_time_filter do
  name        "Remaining time filter"
  author      "Manage Petro"
  description "Adds an IssueQuery filter for remaining time (estimated - spent)"
  version     "0.4.1"
  requires_redmine version_or_higher: "6.1.0"
end

# --- BOOT-TIME PATCH (reliable in production) ---
begin
  require_dependency "issue_query"
  require_relative "lib/redmine_remaining_time_filter/issue_query_patch"

  unless IssueQuery < RedmineRemainingTimeFilter::IssueQueryPatch
    IssueQuery.prepend RedmineRemainingTimeFilter::IssueQueryPatch
  end
rescue => e
  # Make failures visible in production.log
  Rails.logger.error "[remaining_time_filter] patch failed: #{e.class}: #{e.message}"
  Rails.logger.error e.backtrace.join("\n")
end

# --- DEV RELOAD SUPPORT (optional, harmless in production) ---
Rails.application.config.to_prepare do
  begin
    require_dependency "issue_query"
    require_relative "lib/redmine_remaining_time_filter/issue_query_patch"

    unless IssueQuery < RedmineRemainingTimeFilter::IssueQueryPatch
      IssueQuery.prepend RedmineRemainingTimeFilter::IssueQueryPatch
    end
  rescue => e
    Rails.logger.error "[remaining_time_filter] to_prepare failed: #{e.class}: #{e.message}"
  end
end

