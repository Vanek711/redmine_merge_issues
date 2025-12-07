class MergeService
    def initialize(issue_a, issue_b)
      @issue_a = issue_a
      @issue_b = issue_b
    end
  
    def merge!
      ActiveRecord::Base.transaction do
        merge_notes
        merge_attachments
        merge_description
        add_merge_notification
        @issue_b.reload.destroy
      end
    end
  
    private
  
    def merge_notes
      @issue_b.journals.each do |journal|
        journal.update!(journalized: @issue_a)
      end
    end
  
    def merge_attachments
      @issue_b.attachments.each do |attachment|
        attachment.update!(container: @issue_a)
      end
    end
  
    def merge_description
      @issue_a.description += "\n\n---\n\n" + @issue_b.description
      @issue_a.save!
    end
  
    def add_merge_notification
      note_content = "Слияние задачи ##{@issue_b.id} с данной задачей. Информация по задаче B:\n"
      note_content += "Тема: #{@issue_b.subject}\n"
      note_content += "Статус: #{@issue_b.status.name}\n"
      note_content += "Приоритет: #{@issue_b.priority.name}\n"
      note_content += "Назначена: #{@issue_b.assigned_to ? @issue_b.assigned_to.name : 'Не назначена'}\n"
      note_content += "Автор: #{@issue_b.author.name}\n"
      note_content += "Дата создания: #{@issue_b.created_on}\n"
      note_content += "Последнее изменение: #{@issue_b.updated_on}\n"
  
      # Ajout des champs personnalisés de l'issue B
      if @issue_b.custom_field_values.any?
        note_content += "\nПользовательские поля:\n"
        @issue_b.custom_field_values.each do |custom_field_value|
          field_name = custom_field_value.custom_field.name
          field_value = custom_field_value.value
          note_content += "- #{field_name}: #{field_value}\n"
        end
      end
  
      @issue_a.journals.create!(notes: note_content, user: User.current)
    end
  end
  
