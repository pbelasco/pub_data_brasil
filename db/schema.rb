# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20091030132659) do

  create_table "andamentos", :force => true do |t|
    t.integer  "proposicao_id"
    t.date     "data"
    t.text     "titulo"
    t.text     "descricao"
    t.integer  "anexo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "media_link"
    t.string   "local"
    t.integer  "id_sileg"
  end

  create_table "anexos", :force => true do |t|
    t.string   "titulo"
    t.integer  "andamento_id"
    t.integer  "poposicao_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "apensas", :force => true do |t|
    t.integer  "original"
    t.integer  "apensada"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bdrb_job_queues", :force => true do |t|
    t.text     "args"
    t.string   "worker_name"
    t.string   "worker_method"
    t.string   "job_key"
    t.integer  "taken"
    t.integer  "finished"
    t.integer  "timeout"
    t.integer  "priority"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "archived_at"
    t.string   "tag"
    t.string   "submitter_info"
    t.string   "runner_info"
    t.string   "worker_key"
    t.datetime "scheduled_at"
  end

  create_table "paginas", :force => true do |t|
    t.string   "titulo"
    t.string   "secao"
    t.text     "conteudo"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "proposicaos", :force => true do |t|
    t.integer  "id_sileg"
    t.string   "descricao"
    t.string   "link"
    t.string   "orgao"
    t.string   "autor"
    t.date     "apresentacao"
    t.text     "ementa"
    t.text     "despacho"
    t.text     "situacao"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "media_link"
    t.text     "explicacao"
    t.text     "apreciacao"
    t.text     "tramitacao"
    t.string   "acessoria_de"
    t.string   "autor_link"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "taggeds", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "proposicao_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tags", :force => true do |t|
    t.string   "termo"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
