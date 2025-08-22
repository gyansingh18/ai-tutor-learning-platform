# Access Code Implementation for User Registration

## Overview
This implementation adds access code validation to the user registration process. New users must provide a valid access code to sign up, with different codes for students and administrators. The system now supports grade-restricted access codes.

## Access Codes
- **Student Access Code**: `ai-tutor-93105` (Full access to all grades)
- **Grade-Restricted Access Code**: `grand-public-school-daltonganj` (Access to Grade 8 only)
- **Admin Access Code**: `admin@93105M` (Administrator access to all grades)

## Implementation Details

### 1. Custom Registrations Controller
- **File**: `app/controllers/users/registrations_controller.rb`
- **Purpose**: Overrides Devise's default registration controller to add access code validation
- **Key Features**:
  - Validates access codes before user creation
  - Automatically determines user role based on access code
  - Sets grade restrictions based on access code
  - Prevents registration with invalid access codes

### 2. Database Changes
- **Migration**: `db/migrate/20250819032919_add_access_code_to_users.rb`
- **Purpose**: Adds `access_code` column to users table
- **Migration**: `db/migrate/20250822031125_add_allowed_grade_to_users.rb`
- **Purpose**: Adds `allowed_grade` column to users table for grade restrictions
- **Note**: Access code is stored as a virtual attribute (not persisted after validation)

### 3. User Model Updates
- **File**: `app/models/user.rb`
- **Changes**:
  - Added `access_code` virtual attribute
  - Added `allowed_grade` field for grade restrictions
  - Added validation for access code presence during creation
  - Added methods to check grade access permissions

### 4. Grade Access Control
- **Method**: `can_access_grade?(grade)` - Checks if user can access a specific grade
- **Method**: `grade_restriction_message` - Returns user-friendly restriction message
- **Logic**: 
  - Admins can access all grades
  - Users with no grade restriction can access all grades
  - Users with grade restrictions can only access their specified grade

### 5. Controller Updates
- **Grades Controller**: Filters available grades based on user permissions
- **Subjects Controller**: Ensures users only access subjects within their allowed grade
- **Chapters Controller**: Restricts chapter access to user's allowed grade
- **Home Controller**: Shows only accessible grade content
- **Dashboard Controller**: Displays content based on grade restrictions

### 6. Registration Form Updates
- **File**: `app/views/devise/registrations/new.html.erb`
- **Changes**:
  - Added access code input field
  - Added helpful text showing all valid access codes
  - Made access code field required

### 7. Route Configuration
- **File**: `config/routes.rb`
- **Changes**: Updated Devise routes to use custom registrations controller

### 8. Application Controller Updates
- **File**: `app/controllers/application_controller.rb`
- **Changes**: Added `access_code` and `allowed_grade` to permitted parameters for sign up

## How It Works

1. **User Registration**: When a user attempts to register, they must provide an access code
2. **Access Code Validation**: The system validates the access code against the predefined codes
3. **Role Assignment**: The user's role is automatically determined based on the access code provided
4. **Grade Restriction**: The user's allowed grade is set based on the access code
5. **User Creation**: If validation passes, the user is created with the appropriate role and grade restrictions
6. **Content Filtering**: Throughout the application, content is filtered based on user's grade permissions
7. **Error Handling**: If validation fails, an error message is displayed and registration is prevented

## Security Features

- Access codes are hardcoded in the controller (not stored in database)
- Role assignment is automatic and cannot be manipulated by users
- Grade restrictions are enforced at the controller level
- Invalid access codes prevent user registration entirely
- Access codes are case-sensitive
- Grade access is checked on every relevant controller action

## Testing

The implementation includes comprehensive tests in `test/controllers/users/registrations_controller_test.rb` covering:
- Valid student access code registration
- Valid admin access code registration
- Invalid access code rejection
- Missing access code handling

## Usage

### For Students with Full Access
1. Navigate to `/users/sign_up`
2. Fill in email and password
3. Select "Student" role
4. Enter access code: `ai-tutor-93105`
5. Submit form
6. Access all grades and content

### For Students with Grade 8 Access Only
1. Navigate to `/users/sign_up`
2. Fill in email and password
3. Select "Student" role
4. Enter access code: `grand-public-school-daltonganj`
5. Submit form
6. Access only Grade 8 content

### For Administrators
1. Navigate to `/users/sign_up`
2. Fill in email and password
3. Select "Admin" role
4. Enter access code: `admin@93105M`
5. Submit form
6. Access all grades and administrative functions

## Grade Restriction Behavior

### Users with `ai-tutor-93105` Access Code
- Can access all grades (6, 7, 8, 9, 10, 11, 12)
- No restrictions on content viewing
- Full learning platform access

### Users with `grand-public-school-daltonganj` Access Code
- Can only access Grade 8 content
- Will be redirected with error message if trying to access other grades
- Limited to Grade 8 subjects and chapters
- Dashboard shows only Grade 8 content

### Administrators
- Can access all grades and content
- No grade restrictions
- Full administrative privileges

## Future Enhancements

- Store access codes in environment variables for better security
- Add access code expiration functionality
- Implement access code generation for different user groups
- Add audit logging for access code usage
- Support multiple grade access (e.g., Grades 8-10)
- Add time-based access restrictions
- Implement access code sharing and management system


