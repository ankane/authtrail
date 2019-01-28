require_relative "test_helper"

class AuthTrailTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::AuthTrail::VERSION
  end

  def test_that_geocode_job_inherits_from_active_job_base_if_application_job_not_defined
    fork {
      define_active_job_base
      require_relative "../app/jobs/auth_trail/geocode_job.rb"
      assert(AuthTrail::GeocodeJob.superclass == ActiveJob::Base)
    }
  end

  def test_that_geocode_job_inherits_from_application_job_if_application_job_defined
    fork {
      define_active_job_base
      define_application_job
      require_relative "../app/jobs/auth_trail/geocode_job.rb"
      assert(AuthTrail::GeocodeJob.superclass == ApplicationJob)
    }
  end

  private

    def define_active_job_base
      Object.const_set('ActiveJob', Module.new { const_set('Base', Class.new) })
    end

    def define_application_job
      Object.const_set('ApplicationJob', Class.new)
    end

end
