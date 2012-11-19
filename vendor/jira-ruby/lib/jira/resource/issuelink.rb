require 'cgi'

module JIRA
  module Resource

    class IssuelinkFactory < JIRA::BaseFactory # :nodoc:
    end

    class Issuelink < JIRA::Base

      require File.join(File.dirname(__FILE__), 'issue')
      has_one :type,         :class => JIRA::Resource::Issuelinktype
      has_one :inwardIssue,  :class => JIRA::Resource::Issue
      has_one :outwardIssue, :class => JIRA::Resource::Issue

      def self.all(client)
        collected_ids = Array.new
        collected_links = Array.new

        ids = client.Issue.all.each do |issue|
          issue.issuelinks.each do |link|
            unless collected_ids.include?(link.id)
              collected_ids << link.id
              response = client.get(client.options[:rest_base_path] + "/issueLink/#{link.id}")
              json = parse_json(response.body)
              collected_links << client.Issuelink.build(json)
            end
          end
        end

        collected_links
      end

    end
  end
end
