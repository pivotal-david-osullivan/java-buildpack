require 'java_buildpack/container'
require 'java_buildpack/container/dist_zip_like'
require 'java_buildpack/util/dash_case'
require 'java_buildpack/util/spring_boot_utils'

module JavaBuildpack
  module Container

    # Encapsulates the detect, compile, and release functionality for Spring Boot applications.
    class SpringBootCDS < JavaBuildpack::Component::BaseComponent
        include JavaBuildpack::Util

      # Creates an instance
      #
      # @param [Hash] context a collection of utilities used the component
      def initialize(context)
        super(context)
        @spring_boot_utils = JavaBuildpack::Util::SpringBootUtils.new
      end

      # (see JavaBuildpack::Component::BaseComponent#detect)
      def detect
        SpringBootCDS.to_s.dash_case
       #supports? ? SpringBootCDS.to_s.dash_case : nil
      end

      # (see JavaBuildpack::Container::DistZipLike#release)
      def release
        @droplet.java_opts.add_preformatted_options"#{CDS_ARCHIVE_PROPERTY}#{CDS_ARCHIVE_FILE}"
        @droplet.java_opts.add_preformatted_options "#{AOT_PROPERTY}"

        @droplet.environment_variables
        .add_environment_variable('SERVER_PORT', '$PORT')

        release_text(classpath)
      end

      def release_text(classpath)
        start = JavaBuildpack::Util::JavaMainUtils.main_class(@application)
        [
          @droplet.environment_variables.as_env_vars,
          'eval',
          'exec',
          "#{qualify_path @droplet.java_home.root, @droplet.root}/bin/java",
          '$JAVA_OPTS',
          classpath,
          start
        ].flatten.compact.join(' ')
      end

      def arguments
        "#{CDS_ARCHIVE_PROPERTY}#{CDS_ARCHIVE_FILE}"
        "#{AOT_PROPERTY}"
      end

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile

        with_timing 'Performing CDS Training Run', true do
          shell "#{java} #{AOT_PROPERTY} #{CONTEXT_PROPERTY} #{CDS_TRAINING_ARCHIVE}#{CDS_ARCHIVE_FILE} -jar #{@application.root}/#{cds_jar}"
        end
      end

      protected

      # (see JavaBuildpack::Container::DistZipLike#id)
      def id
        "#{SpringBootCDS.to_s.dash_case}=#{version}"
      end

      # (see JavaBuildpack::Container::DistZipLike#supports?)
      def supports?
        @spring_boot_utils.is?(@application) && version_supported? && @configuration['enabled']
      end

      def version_supported?
        @spring_boot_utils.version_at_least?(@application, '3.3.0')
      end

      def classpath
        cp = "-cp $PWD/" + cds_jar
      end

      def cds_jar()
        "#{@application.details['application_name']}.jar" || "cds-runner.jar"
      end

      private

      CONTEXT_PROPERTY = '-Dspring.context.exit=onRefresh'

      AOT_PROPERTY = '-Dspring.aot.enabled=true'

      CDS_ARCHIVE_FILE = 'application.jsa'

      CDS_TRAINING_ARCHIVE = '-XX:ArchiveClassesAtExit='

      CDS_ARCHIVE_PROPERTY = '-XX:SharedArchiveFile='

      private_constant :CDS_ARCHIVE_PROPERTY, :CONTEXT_PROPERTY, :AOT_PROPERTY

      def java
        @droplet.java_home.root + 'bin/java'
      end

    end

  end
end