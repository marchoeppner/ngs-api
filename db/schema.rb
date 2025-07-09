# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2025_07_09_101435) do

  create_table "jobs", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "status"
    t.string "command"
    t.string "run_dir"
    t.string "options"
    t.string "log"
    t.date "date_registered"
    t.date "date_updated"
    t.integer "slurm_id"
    t.integer "attempts"
  end

  create_table "libraries", force: :cascade do |t|
    t.integer "run_id"
    t.string "name"
    t.string "R1"
    t.string "R2"
    t.date "date_registered"
    t.integer "lane"
    t.index ["name", "lane", "run_id"], name: "uniq_library_by_lane_and_run", unique: true
  end

  create_table "pipelines", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "version"
    t.string "template"
    t.string "samplesheet_format"
    t.index ["name"], name: "uniq_pipeline", unique: true
  end

  create_table "runs", force: :cascade do |t|
    t.string "platform"
    t.string "name"
    t.string "description"
    t.string "folder"
    t.date "date_registered"
  end

end
