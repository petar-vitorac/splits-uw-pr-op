# frozen_string_literal: true

require 'dotenv/load'
require 'octokit'

REPOS = ENV['REPOS'].split
MAX_ADDITIONS = ENV['MAX_ADDITIONS'].to_i
SPLITS = 'splits uw pr op'
SIGNATURE = "\n--\nThis comment was automatically posted because the additions in your PR have exceeded #{MAX_ADDITIONS} lines.\nhttps://github.com/petar-vitorac/splits-uw-pr-op".freeze

# Shoutout to Quivr
puts SPLITS

client = Octokit::Client.new(access_token: ENV['GH_ACCESS_TOKEN'])
username = client.user()[:login]

REPOS.each do |repo|
  client.pulls(repo, state: 'open').map { |pr| pr[:number] }.each do |pr|
    if client.pull(repo, pr)[:additions] > MAX_ADDITIONS
      unless client.issue_comments(repo, pr).any? { |comment| comment[:body].include?(SPLITS) && comment[:user][:login] == username }
        client.add_comment(repo, pr, SPLITS + SIGNATURE)
        puts "Commented on #{repo}, PR \##{pr}"
      end
    else
      existing_comment = client.issue_comments(repo, pr).filter { |comment| comment[:body].include?(SPLITS) && comment[:user][:login] == username }[0]
      if existing_comment
        client.delete_comment(repo, existing_comment[:id])
        puts "Deleted comment on #{repo}, PR \##{pr}"
      end
    end
  end
end
