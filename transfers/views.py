from django.db.transaction import commit
from django.http import request
from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from .models import EmployeeTransfer
from .forms import EmployeeTransferForm

# Create your views here.

@login_required
def request_transfer(request):
    if request.method == "POST":
        form = EmployeeTransferForm(request.POST)
        if form.is_valid():
            transfers_request = form.save(commit = False )
            transfers_request_requested_by = request.user
            transfers_request.save()
            messages.success(request, "Transfer request submitted successfully.")
            return redirect("transfer_list")
    else:
        form = EmployeeTransferForm()
    return render(request, "transfers/")



