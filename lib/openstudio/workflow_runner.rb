require_relative 'workflow/util/type_casting'
include OpenStudio::Workflow::Util::TypeCasting

# Extend OS Runner to persist measure information throughout the workflow
 # @todo (rhorsey) WorkflowRunner should be created at the beginning of a workflow and carried throughout - DLM
class WorkflowRunner < OpenStudio::Ruleset::OSRunner
  # Allow former arguments and the current weatherfile path to be set and read
  # TODO: Consider having the former arguments passed in in initialization, and define as attr_reader
  # @todo (rhorsey) some of this stuff is in C++ - DLM
  attr_accessor :former_workflow_arguments #DLM - deprecate in OS 2.0
  attr_accessor :weatherfile_path #DLM - deprecate?

  # Add in @workflow_arguments
  # @todo (rhorsey) WorkflowRunner should persist throughout the life of a Workflow, it should rely on methods in OSRunner when possible- DLM
  # @todo (rhorsey) analysis_hash and datapoint_hash should not be present - DLM
  # @todo (rhorsey) what is output_attributes for? - DLM
  def initialize(multi_logger, workflow_hash, analysis_hash, datapoint_hash, output_attributes)
    @multi_logger = multi_logger
    @workflow = workflow_hash
    @workflow_json = nil
    @analysis = analysis_hash
    @datapoint = datapoint_hash
    @results = output_attributes
    @workflow_arguments = nil
    
    begin
      # OpenStudio 2.X
      @multi_logger.info JSON.pretty_generate(workflow)
      @workflow_json = OpenStudio::WorkflowJSON.new(JSON.fast_generate(workflow))
      @workflow_json.setOswDir(".") # @todo (rhorsey) - get the directory of the osw
      @multi_logger.info "WorkflowJSON available #{@workflow_json}"
      super(@workflow_json)
    rescue Exception => e 
      # OpenStudio 1.X
      @multi_logger.warn e.message
      @multi_logger.info "WorkflowJSON unavailable"
      super()
    end
  end

  def past_results
    @results
  end

  def workflow
    @workflow
  end
  
  def workflow_json
    @workflow_json
  end

  def analysis
    @analysis
  end

  def datapoint
    @datapoint
  end

  # Overloaded argument parsing
  # validateUserArguments(const std::vector<OSArgument>& script_arguments, const std::map<std::string, OSArgument>& user_arguments);
  # DLM: the only purpose of this call is to popluate @workflow_arguments.  Once WorkflowJSON is merged we will not need this, we can then remove the TypeCasting module
  def validateUserArguments(script_arguments, user_arguments)
    @workflow_arguments = {}
    user_arguments.each do |hash|
      value = cast_os_type(hash, user_arguments)
      @workflow_arguments[hash.to_sym] = value if value
    end

    super
  end

  # Overload registerInfo
  def registerInfo(message)
    super
    @multi_logger.info message
  end

  # Overload registerInfo
  def registerWarning(message)
    super
    @multi_logger.warn message
  end

  # Overload registerError
  def registerError(message)
    super
    @multi_logger.error message
  end

  # Overload registerInitialCondition
  def registerInitialCondition(message)
    super
    @multi_logger.info message
  end

  # Overload registerFinalCondition
  def registerFinalCondition(message)
    super
    @multi_logger.info message
  end
end
