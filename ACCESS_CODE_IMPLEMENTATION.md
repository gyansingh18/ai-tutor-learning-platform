# Access Code Implementation for User Registration

## Overview
This implementation adds access code validation to the user registration process. New users must provide a valid access code to sign up, with different codes for students and administrators.

## Access Codes
- **Student Access Code**: `ai-tutor-93105`
- **Admin Access Code**: `admin@93105M`

## Implementation Details

### 1. Custom Registrations Controller
- **File**: `app/controllers/users/registrations_controller.rb`
- **Purpose**: Overrides Devise's default registration controller to add access code validation
- **Key Features**:
  - Validates access codes before user creation
  - Automatically determines user role based on access code
  - Prevents registration with invalid access codes

### 2. Database Changes
- **Migration**: `db/migrate/20250819032919_add_access_code_to_users.rb`
- **Purpose**: Adds `access_code` column to users table
- **Note**: Access code is stored as a virtual attribute (not persisted after validation)

### 3. User Model Updates
- **File**: `app/models/user.rb`
- **Changes**:
  - Added `access_code` virtual attribute
  - Added validation for access code presence during creation

### 4. Registration Form Updates
- **File**: `app/views/devise/registrations/new.html.erb`
- **Changes**:
  - Added access code input field
  - Added helpful text showing valid access codes
  - Made access code field required

### 5. Route Configuration
- **File**: `config/routes.rb`
- **Changes**: Updated Devise routes to use custom registrations controller

### 6. Application Controller Updates
- **File**: `app/controllers/application_controller.rb`
- **Changes**: Added `access_code` to permitted parameters for sign up

## How It Works

1. **User Registration**: When a user attempts to register, they must provide an access code
2. **Access Code Validation**: The system validates the access code against the predefined codes
3. **Role Assignment**: The user's role is automatically determined based on the access code provided
4. **User Creation**: If validation passes, the user is created with the appropriate role
5. **Error Handling**: If validation fails, an error message is displayed and registration is prevented

## Security Features

- Access codes are hardcoded in the controller (not stored in database)
- Role assignment is automatic and cannot be manipulated by users
- Invalid access codes prevent user registration entirely
- Access codes are case-sensitive

## Testing

The implementation includes comprehensive tests in `test/controllers/users/registrations_controller_test.rb` covering:
- Valid student access code registration
- Valid admin access code registration
- Invalid access code rejection
- Missing access code handling

## Usage

### For Students
1. Navigate to `/users/sign_up`
2. Fill in email and password
3. Select "Student" role
4. Enter access code: `ai-tutor-93105`
5. Submit form

### For Administrators
1. Navigate to `/users/sign_up`
2. Fill in email and password
3. Select "Admin" role
4. Enter access code: `admin@93105M`
5. Submit form

## Future Enhancements

- Store access codes in environment variables for better security
- Add access code expiration functionality
- Implement access code generation for different user groups
- Add audit logging for access code usage

