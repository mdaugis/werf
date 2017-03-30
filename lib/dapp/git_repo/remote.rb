module Dapp
  module GitRepo
    # Normal Git repo
    class Remote < Base
      def initialize(dimg, name, url:)
        super(dimg, name)

        @url = url

        dimg.project.log_secondary_process(dimg.project.t(code: 'process.git_artifact_clone', data: { name: name }), short: true) do
          begin
            Rugged::Repository.clone_at(url, path, bare: true)
          rescue Rugged::NetworkError, Rugged::SslError => e
            raise Error::Rugged, code: :rugged_remote_error, data: { message: e.message, url: url }
          end
        end unless File.directory?(path)
      end

      def fetch!(branch = nil)
        branch ||= self.branch
        dimg.project.log_secondary_process(dimg.project.t(code: 'process.git_artifact_fetch', data: { name: name }), short: true) do
          git_bare.fetch('origin', [branch])
          raise Error::Rugged, code: :branch_not_exist_in_remote_git_repository, data: { branch: branch, url: url } unless branch_exist?(branch)
        end unless dimg.ignore_git_fetch || dimg.project.dry_run?
      end

      def branch_exist?(name)
        git_bare.branches.exist?(branch_format(name))
      end

      def latest_commit(name)
        git_bare.ref("refs/remotes/#{branch_format(name)}").target_id
      end

      def cleanup!
        super
        FileUtils.rm_rf path
      end

      def lookup_commit(commit)
        super
      rescue Rugged::OdbError, TypeError => _e
        raise Error::Rugged, code: :commit_not_found_in_remote_git_repository, data: { commit: commit, url: url }
      end

      protected

      attr_reader :url

      private

      def branch_format(name)
        "origin/#{name.reverse.chomp('origin/'.reverse).reverse}"
      end
    end
  end
end