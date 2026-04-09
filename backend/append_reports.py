import os

file_path = "d:\\R_Technologies_Intership\\pos-realstates-main\\backend\\real_estate\\reports.py"

content_to_append = """

def generate_dealer_commission_report_pdf(sales, dealer=None, start_date=None, end_date=None):
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import A4, landscape
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
    from reportlab.lib.units import cm
    from io import BytesIO

    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=landscape(A4))
    story = []
    styles = getSampleStyleSheet()
    
    title = "Dealer Commission Report"
    if dealer: title += f" - {dealer}"
    story.append(Paragraph(title, styles['Heading1']))
    story.append(Spacer(1, 0.5*cm))
    
    data = [['Date', 'Dealer', 'Project', 'Plot No.', 'Plot Price', 'Commission %', 'Comm. Value', 'Paid', 'Remaining', 'Status']]
    for s in sales:
        data.append([
            s.sale_date.strftime('%Y-%m-%d') if s.sale_date else '-',
            s.dealer.name if s.dealer else '-',
            s.plot.project.name,
            s.plot.plot_number,
            f"{s.total_price:,.0f}",
            f"{s.dealer.commission_percentage}%" if s.dealer else "-",
            f"{s.dealer_commission:,.0f}",
            f"{s.dealer_paid_amount:,.0f}",
            f"{(s.dealer_commission - s.dealer_paid_amount):,.0f}",
            s.commission_status
        ])
        
    t = Table(data)
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('GRID', (0,0), (-1,-1), 0.5, colors.black),
    ]))
    story.append(t)
    doc.build(story)
    buffer.seek(0)
    return buffer

def generate_client_payment_report_pdf(sales, start_date=None, end_date=None):
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import A4, landscape
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
    from reportlab.lib.units import cm
    from io import BytesIO

    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=landscape(A4))
    story = []
    styles = getSampleStyleSheet()
    
    story.append(Paragraph("Client Payment & Due Report", styles['Heading1']))
    story.append(Spacer(1, 0.5*cm))
    
    data = [['Date', 'Client', 'Phone', 'Project', 'Plot No.', 'Total Price', 'Received', 'Balance', 'Status']]
    for s in sales:
        data.append([
            s.sale_date.strftime('%Y-%m-%d') if s.sale_date else '-',
            s.customer.name,
            s.customer.phone,
            s.plot.project.name,
            s.plot.plot_number,
            f"{s.total_price:,.0f}",
            f"{s.total_received:,.0f}",
            f"{s.current_balance:,.0f}",
            s.commission_status
        ])
        
    t = Table(data)
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('GRID', (0,0), (-1,-1), 0.5, colors.black),
    ]))
    story.append(t)
    doc.build(story)
    buffer.seek(0)
    return buffer

def generate_profit_loss_report_pdf(incomes, expenses, start_date=None, end_date=None):
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
    from reportlab.lib.units import cm
    from io import BytesIO

    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4)
    story = []
    styles = getSampleStyleSheet()
    
    story.append(Paragraph("Profit and Loss Report", styles['Heading1']))
    story.append(Spacer(1, 0.5*cm))
    
    total_inc = sum(i.amount for i in incomes)
    total_exp = sum(e.amount for e in expenses)
    profit = total_inc - total_exp
    
    data = [
        ['Type', 'Total Amount'],
        ['Total Income', f"{total_inc:,.0f}"],
        ['Total Expenses', f"{total_exp:,.0f}"],
        ['Net Profit/Loss', f"{profit:,.0f}"]
    ]
        
    t = Table(data)
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('GRID', (0,0), (-1,-1), 0.5, colors.black),
        ('FONTNAME', (0, -1), (-1, -1), 'Helvetica-Bold'),
    ]))
    story.append(t)
    doc.build(story)
    buffer.seek(0)
    return buffer

def generate_cash_flow_report_pdf(transactions, start_date=None, end_date=None):
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import A4, landscape
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
    from reportlab.lib.units import cm
    from io import BytesIO

    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=landscape(A4))
    story = []
    styles = getSampleStyleSheet()
    
    story.append(Paragraph("Cash Flow Report", styles['Heading1']))
    story.append(Spacer(1, 0.5*cm))
    
    data = [['Date', 'Type', 'Category', 'Description', 'Income Amount', 'Expense Amount']]
    net = 0
    total_in = 0
    total_out = 0
    for t in transactions:
        amount = t['amount']
        if t['type'] == 'Income':
            total_in += amount
            net += amount
            data.append([t['date'].strftime('%Y-%m-%d') if t['date'] else '-', 'Income', t['category'], t.get('description', ''), f"{amount:,.0f}", "-"])
        else:
            total_out += amount
            net -= amount
            data.append([t['date'].strftime('%Y-%m-%d') if t['date'] else '-', 'Expense', t['category'], t.get('description', ''), "-", f"{amount:,.0f}"])
            
    data.append(["TOTAL", "", "", "", f"{total_in:,.0f}", f"{total_out:,.0f}"])
    data.append(["NET CASH FLOW", "", "", "", f"{net:,.0f}", ""])
            
    t = Table(data)
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('GRID', (0,0), (-1,-1), 0.5, colors.black),
        ('FONTNAME', (0, -2), (-1, -1), 'Helvetica-Bold'),
    ]))
    story.append(t)
    doc.build(story)
    buffer.seek(0)
    return buffer
"""

with open(file_path, "a") as f:
    f.write(content_to_append)

print("Appended PDF generation functions.")
