// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract JobPortal {
    enum ExperienceLevel { EntryLevel, MidLevel, SeniorLevel }

    struct Profile {
        string name;
        string email;
        string skills;
        string jobTypeLookingFor; // New field to specify the type of job applicant is seeking
        bool isCreated;
        mapping(address => string[]) interviewReviews;
    }

    struct JobRequirement {
        uint requirementId;
        address recruiter;
        string title;
        string description;
        bool isActive;
        string location;
        string jobType;
        uint postedAt;
        ExperienceLevel experienceLevel;
    }

    struct Application {
        uint applicationId;
        uint jobId;
        address applicant;
        bool isRejected;
        string rejectionReason;
        bool isProcessed;
    }

    mapping(address => Profile) public profiles;
    mapping(uint => JobRequirement) public jobRequirements;
    mapping(uint => Application) public applications;

    uint public requirementCount;
    uint public applicationCount;

    mapping(address => bool) public employers;

    event ProfileCreated(address indexed applicant, string name, string email, string skills, string jobTypeLookingFor);
    event RequirementPosted(uint indexed requirementId, address indexed recruiter, string title, string description);
    event ApplicationSubmitted(uint indexed applicationId, uint indexed jobId, address indexed applicant);
    event ApplicationRejected(uint indexed applicationId, string rejectionReason);
    event FilteredJobs(address indexed applicant, uint[] jobIds);
    event InterviewReviewShared(address indexed recruiter, address indexed applicant, string review);

    constructor() {
        requirementCount = 0;
        applicationCount = 0;
    }

    function createProfile(
        string memory _name,
        string memory _email,
        string memory _skills,
        string memory _jobTypeLookingFor
    ) external {
        require(!profiles[msg.sender].isCreated, "Profile already exists for this address");

    profiles[msg.sender].name = _name;
    profiles[msg.sender].email = _email;
    profiles[msg.sender].skills = _skills;
    profiles[msg.sender].jobTypeLookingFor = _jobTypeLookingFor;
    profiles[msg.sender].isCreated = true;
    emit ProfileCreated(msg.sender, _name, _email, _skills, _jobTypeLookingFor);
    profiles[msg.sender].interviewReviews[msg.sender] = new string[](0);
    }

    function postJobRequirement(
        string memory _title,
        string memory _description,
        string memory _location,
        string memory _jobType,
        uint _postedAt,
        uint _experienceLevel
    ) external {
        require(employers[msg.sender], "Only registered employers can post job requirements");
        requirementCount++;
        jobRequirements[requirementCount] = JobRequirement(
            requirementCount,
            msg.sender,
            _title,
            _description,
            true,
            _location,
            _jobType,
            _postedAt,
            ExperienceLevel(_experienceLevel)
        );
        emit RequirementPosted(requirementCount, msg.sender, _title, _description);
    }

    function applyForJob(uint _jobId) external {
        require(jobRequirements[_jobId].isActive, "Job requirement not available");
        applicationCount++;
        applications[applicationCount] = Application(applicationCount, _jobId, msg.sender, false, "", false);
        emit ApplicationSubmitted(applicationCount, _jobId, msg.sender);
    }

    function rejectApplicant(uint _applicationId, string memory _rejectionReason) external {
        require(jobRequirements[applications[_applicationId].jobId].recruiter == msg.sender, "You can only reject applicants for your own jobs");
        require(!applications[_applicationId].isProcessed, "Application already processed");
        applications[_applicationId].isRejected = true;
        applications[_applicationId].rejectionReason = _rejectionReason;
        applications[_applicationId].isProcessed = true;
        emit ApplicationRejected(_applicationId, _rejectionReason);
    }

    function filterJobs(
        string memory _location,
        string memory _jobType,
        uint _experienceLevel,
        uint _postedAfter
    ) external {
        uint[] memory filteredJobs = new uint[](requirementCount);
        uint count = 0;

        for (uint i = 1; i <= requirementCount; i++) {
            JobRequirement storage requirement = jobRequirements[i];
            if (
                requirement.isActive &&
                compareStrings(requirement.location, _location) &&
                compareStrings(requirement.jobType, _jobType) &&
                requirement.experienceLevel == ExperienceLevel(_experienceLevel) &&
                requirement.postedAt >= _postedAfter
            ) {
                filteredJobs[count] = i;
                count++;
            }
        }

        uint[] memory result = new uint[](count);
        for (uint j = 0; j < count; j++) {
            result[j] = filteredJobs[j];
        }

        emit FilteredJobs(msg.sender, result);
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function registerAsEmployer() external {
        employers[msg.sender] = true;
    }

    function unregisterAsEmployer() external {
        delete employers[msg.sender];
    }

    function shareInterviewReview(address _recruiter, string memory _review) external {
        require(profiles[_recruiter].isCreated, "Recruiter profile doesn't exist");

        string[] storage reviews = profiles[_recruiter].interviewReviews[msg.sender];
        reviews.push(_review);
        emit InterviewReviewShared(_recruiter, msg.sender, _review);
    }
}