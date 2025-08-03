class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Enums
  enum role: { student: 0, admin: 1 }

  # Relationships
  has_many :questions, dependent: :destroy
  has_many :pdf_materials, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :role, presence: true

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
end
