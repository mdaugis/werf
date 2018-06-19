module Dapp
  module Dimg
    module GitRepo
      class Remote < Base
        CACHE_VERSION = 1

        attr_reader :url
        attr_reader :path

        class << self
          def get_or_create(dapp, name, url:, ignore_git_fetch: false)
            key         = [url, ignore_git_fetch]
            inverse_key = [url, !ignore_git_fetch]

            repositories[key] ||= begin
              if repositories.key?(inverse_key)
                repositories[inverse_key]
              else
                new(dapp, name, url: url)
              end.tap do |repo|
                repo.fetch! unless ignore_git_fetch
              end
            end
          end

          def repositories
            @repositories ||= {}
          end
        end

        def initialize(dapp, name, url:)
          super(dapp, name)

          @url = url

          _with_lock do
            dapp.log_secondary_process(dapp.t(code: 'process.git_artifact_clone', data: { url: url }), short: true) do
              begin
                if [:https, :ssh].include?(remote_origin_url_protocol) && !Rugged.features.include?(remote_origin_url_protocol)
                  raise Error::Rugged, code: :rugged_protocol_not_supported, data: { url: url, protocol: remote_origin_url_protocol }
                end

                Rugged::Repository.clone_at(url, path.to_s, bare: true, credentials: _rugged_credentials)
              rescue Rugged::NetworkError, Rugged::SslError, Rugged::OSError => e
                raise Error::Rugged, code: :rugged_remote_error, data: { message: e.message, url: url }
              end
            end
          end unless path.directory?
        end

        def _with_lock(&blk)
          dapp.lock("remote_git_artifact.#{name}", default_timeout: 600, &blk)
        end

        def _rugged_credentials
          @_rugged_credentials ||= begin
            if remote_origin_url_protocol == :ssh
              host_with_user = url.split(':', 2).first
              username = host_with_user.split('@', 2).reverse.last
              Rugged::Credentials::SshKeyFromAgent.new(username: username)
            end
          end
        end

        def path
          Pathname(dapp.build_path("remote_git_repo", CACHE_VERSION.to_s, name).to_s)
        end

        def fetch!
          _with_lock do
            cfg_path = path.join("config")
            cfg = IniFile.load(cfg_path)
            remote_origin_cfg = cfg['remote "origin"']

            old_url = remote_origin_cfg["url"]
            if old_url and old_url != url
              remote_origin_cfg["url"] = url
              cfg.write(filename: cfg_path)
            end

            dapp.log_secondary_process(dapp.t(code: 'process.git_artifact_fetch', data: { url: url }), short: true) do
              begin
                git.remotes.each { |remote| remote.fetch(credentials: _rugged_credentials) }
              rescue Rugged::SshError => e
                raise Error::Rugged, code: :rugged_remote_error, data: { url: url, message: e.message.strip }
              end
            end
          end unless dapp.dry_run?
        end

        def latest_commit(name)
          git.ref("refs/remotes/#{branch_format(name)}").target_id
        end

        def lookup_commit(commit)
          super
        rescue Rugged::OdbError, TypeError => _e
          raise Error::Rugged, code: :commit_not_found_in_remote_git_repository, data: { commit: commit, url: url }
        end

        protected

        def git
          super(bare: true, credentials: _rugged_credentials)
        end

        private

        def branch_format(name)
          "origin/#{name.reverse.chomp('origin/'.reverse).reverse}"
        end
      end
    end
  end
end
