class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Virtual attribute for access code (not stored in database after validation)
  attr_accessor :access_code

  # Enums
  enum role: { student: 0, admin: 1 }

  # Relationships
  has_many :questions, dependent: :destroy
  has_many :pdf_materials, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :role, presence: true
  validates :access_code, presence: true, on: :create

  # Scopes
  scope :students, -> { where(role: :student) }
  scope :admins, -> { where(role: :admin) }

  # Methods
  def admin?
    role == 'admin'
  end

  def student?
    role == 'student'
  end

  def display_name
    email.split('@').first.titleize
  end

  # Check if user has access to a specific grade
  def can_access_grade?(grade)
    return true if admin? # Admins can access all grades
    return true if allowed_grade.blank? # No grade restriction
    allowed_grade.to_s == grade.to_s
  end

  # Get the grade restriction message
  def grade_restriction_message
    if allowed_grade.present?
      "You can only access Grade #{allowed_grade} content."
    else
      "You have access to all grades."
    end
  end
end
