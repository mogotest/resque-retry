# Extend Resque::Server to add tabs.
module ResqueRetry
  module Server

    def self.included(base)
      base.class_eval {
        helpers do
          # builds a retry key for the specified job.
          def retry_key_for_job(job)
            begin
              klass = Resque.constantize(job['class'])
              if klass.respond_to?(:redis_retry_key)
                klass.redis_retry_key(job['args'])
              else
                nil
              end
            rescue NameError
              nil
            end
          end

          # gets the number of retry attempts for a job.
          def retry_attempts_for_job(job)
            Resque.redis.get(retry_key_for_job(job))
          end
          
          # gets the failure details hash for a job.
          def retry_failure_details(retry_key)
            Resque.decode(Resque.redis["failure_#{retry_key}"])
          end

          # reads a 'local' template file.
          def local_template(path)
            # Is there a better way to specify alternate template locations with sinatra?
            File.read(File.join(File.dirname(__FILE__), "server/views/#{path}"))
          end
        end

        get '/retry' do
          erb local_template('retry.erb')
        end

        get '/retry/:timestamp' do
          erb local_template('retry_timestamp.erb')
        end
      }
    end

  end
end

Resque::Server.tabs << 'Retry'
Resque::Server.class_eval do
  include ResqueRetry::Server
end
