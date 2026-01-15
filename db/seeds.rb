# db/seeds.rb

# Only run in development
return unless Rails.env.development?

puts "🧹 Clearing existing data..."
Event.destroy_all
Task.destroy_all
User.destroy_all

puts "👥 Creating users..."

users_data = [
  { email: 'admin@example.com', password: 'password123', name: 'Admin User', role: 'admin' },
  { email: 'manager@example.com', password: 'password123', name: 'Manager User', role: 'manager' },
  { email: 'member1@example.com', password: 'password123', name: 'Member One', role: 'member' },
  { email: 'member2@example.com', password: 'password123', name: 'Member Two', role: 'member' }
]

users = users_data.map { |u| User.create!(u.merge(password_confirmation: u[:password])) }

admin   = users.find { |u| u.role == 'admin' }
manager = users.find { |u| u.role == 'manager' }
member1 = users.find { |u| u.email == 'member1@example.com' }
member2 = users.find { |u| u.email == 'member2@example.com' }

puts "✅ Created #{User.count} users"

puts "📋 Creating tasks..."

tasks_data = [
  { title: 'Setup development environment', description: 'Install Ruby, Rails, PostgreSQL, and configure project', state: 'draft', creator: manager },
  { title: 'Write API documentation', description: 'Document all API endpoints with examples', state: 'draft', creator: manager },
  { title: 'Implement user authentication', description: 'Add JWT-based authentication to API', state: 'assigned', creator: manager, assignee: member1 },
  { title: 'Create database migrations', description: 'Design and implement database schema', state: 'assigned', creator: manager, assignee: member2 },
  { title: 'Build task management endpoints', description: 'CRUD operations for tasks with proper authorization', state: 'in_progress', creator: manager, assignee: member1 },
  { title: 'Setup CI/CD pipeline', description: 'Configure GitHub Actions for automated testing', state: 'completed', creator: admin, assignee: member2 },
  { title: 'Migrate to MongoDB', description: 'Decided to stick with PostgreSQL instead', state: 'cancelled', creator: admin }
]

tasks = tasks_data.map { |t| Task.create!(t) }

puts "✅ Created #{Task.count} tasks"

puts "🔔 Creating events..."

events_data = [
  { event_type: 'user.created', payload: { user_id: admin.id, email: admin.email } },
  { event_type: 'task.created', payload: { task_id: tasks.first.id, creator_id: manager.id } },
  { event_type: 'task.assigned', payload: { task_id: tasks.find { |t| t.state == 'assigned' }.id, assignee_id: member1.id }, processed_at: 1.hour.ago }
]

events_data.each { |e| Event.create!(e) }

puts "✅ Created #{Event.count} events"

puts "\n🎉 Seed data successfully created!"
puts "\nLogin credentials:"
puts "  Admin:   admin@example.com / password123"
puts "  Manager: manager@example.com / password123"
puts "  Member:  member1@example.com / password123"
