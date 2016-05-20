using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.WindowsAzure.MobileServices;

namespace Humiiapp
{
	public class ToDoService
	{
		private MobileServiceClient _MobileServiceClient;
		private IMobileServiceTable<ManuItem> _ManuItemTable;

		public ToDoService()
		{
			// Init Azure connection
			_MobileServiceClient = new MobileServiceClient("https://hummiiapp.azurewebsites.net");
			_ManuItemTable = _MobileServiceClient.GetTable<ManuItem>();
		}

		public async Task<List<ManuItem>> GetAllItemsAsync()
		{
			var allItems = await _ManuItemTable.ToListAsync();
			return allItems;
		}

		public async Task AddItemAsync(ManuItem item)
		{
			await _ManuItemTable.InsertAsync(item);
		}

		public async Task UpdateItemAsync(ManuItem item)
		{
			await _ManuItemTable.UpdateAsync(item);
		}
	}
}