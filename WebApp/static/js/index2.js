function deleteRow(el) {
    el.parentNode.parentNode.style.display = 'none';
  }
  
  function addEmptyRow() {
    const table = document.querySelector('table');
    const newRow = document.createElement('tr');
    newRow.innerHTML = `<td></td><td></td><td></td><td></td><td></td>
      <td><button onclick="deleteRow(this)">Delete</button></td>`;
    table.appendChild(newRow);
  }
  