from flask import Flask, request, jsonify, redirect, render_template
from dotenv import load_dotenv
import os
import whois
from datetime import datetime
from urllib.parse import urlparse
import requests

load_dotenv()

# Initialize database
from migrate import create_db
create_db()

app = Flask(__name__, static_folder='static')
# Database switch
if os.getenv("DATABASE_TYPE", "MYSQL") == "MYSQL":
    from data_sql import (
        get_contacts, findByNumber, check_contact_exist, search_contacts,
        create_contact, delete_contact, update_contact_in_db,
        create_meeting, get_all_meetings
    )
else:
    from data_mongo import (
        get_contacts, findByNumber, check_contact_exist, search_contacts,
        create_contact, delete_contact, update_contact_in_db
    )

# ------------------ API Routes ------------------
@app.route('/api/contacts', methods=['GET'])
def api_get_contacts():
    return jsonify(get_contacts())

@app.route('/api/contact/<number>', methods=['GET'])
def api_get_contact(number):
    contact = findByNumber(number)
    return jsonify(contact) if contact else (jsonify({"error": "Contact not found"}), 404)

@app.route('/api/contact', methods=['POST'])
def api_create_contact():
    data = request.json
    if not check_contact_exist(data['fullname'], data['email']):
        create_contact(data['fullname'], data['phone'], data['email'], data['gender'], "default.jpg")
        return jsonify({"message": "Contact created successfully"}), 201
    return jsonify({"error": "Contact already exists"}), 400

@app.route('/api/contact/<number>', methods=['PUT'])
def api_update_contact(number):
    data = request.json
    update_contact_in_db(number, data['fullname'], data['phone'], data['email'], data['gender'])
    return jsonify({"message": "Contact updated successfully"})

@app.route('/api/contact/<number>', methods=['DELETE'])
def api_delete_contact(number):
    delete_contact(number)
    return jsonify({"message": "Contact deleted successfully"})

# ------------------ Crawler ------------------
@app.route('/api/scan', methods=['POST'])
def scan_domain():
    data = request.json
    domain = data.get("domain")
    if not domain:
        return jsonify({"error": "Domain is required"}), 400
    try:
        parsed = urlparse(domain).netloc or domain
        w = whois.whois(parsed)
        response = {
            "domain": parsed,
            "whois_name": w.name,
            "org": w.org,
            "emails": w.emails,
            "creation_date": str(w.creation_date),
            "expiration_date": str(w.expiration_date)
        }
        return jsonify(response)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ------------------ Booking ------------------
@app.route('/api/book-meeting', methods=['POST'])
def api_book_meeting():
    data = request.json
    create_meeting(data['name'], data['email'], data['datetime'], data['reason'], "Pending")
    return jsonify({"message": "Meeting booked successfully"}), 201

@app.route('/api/bookings', methods=['GET'])
def get_bookings():
    return jsonify(get_all_meetings())

# ------------------ Security Alerts ------------------
@app.route('/api/alerts', methods=['GET'])
def get_security_alerts():
    try:
        response = requests.get("https://services.nvd.nist.gov/rest/json/cves/2.0?resultsPerPage=5")
        return jsonify(response.json())
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ------------------ Frontend Views ------------------
@app.route('/')
def home():
    return redirect('/DugmaAppDash')

@app.route('/DugmaAppDash')
def view_contacts():
    return render_template('index.html', contacts=get_contacts(), meetings=get_all_meetings())

@app.route('/addContact')
def add_contact():
    return render_template('addContactForm.html')

@app.route('/editContact/<number>')
def edit_contact(number):
    contact = findByNumber(number)
    return render_template('editContactForm.html', contact=contact)

@app.route('/book-meeting')
def book_meeting_view():
    return render_template('bookMeeting.html')

@app.route('/crawl')
def crawl_view():
    return render_template('crawl.html')

@app.route('/alerts')
def alerts_view():
    return render_template('alerts.html')

if __name__ == '__main__':
    app.run(debug=True, port=5052, host='0.0.0.0')
