using Android.App;
using Android.Widget;
using Android.OS;
using Microsoft.WindowsAzure.MobileServices;
using Android.Support.V7.App;
using Android.Support.V4.Widget;
using System;
using System.Threading.Tasks;

namespace Humiiapp
{
	[Activity(Label = "humiiapp", MainLauncher = true, Icon = "@mipmap/icon")]
	public class MainActivity : AppCompatActivity
	{
		private ListView lvItems;
		private EditText etItemText;
		private Button btnAdd;

		protected override void OnCreate(Bundle savedInstanceState)
		{
			base.OnCreate(savedInstanceState);
			SetContentView(Resource.Layout.Main);

			lvItems = FindViewById<ListView>(Resource.Id.lvItems);
			etItemText = FindViewById<EditText>(Resource.Id.etItemText);
			btnAdd = FindViewById<Button>(Resource.Id.btnAdd);
			btnAdd.Click += BtnAdd_Click;

			// Init swipe to refresh
			var slSwipeContainer = FindViewById<SwipeRefreshLayout>(Resource.Id.slSwipeContainer);
			slSwipeContainer.SetColorSchemeResources(Android.Resource.Color.HoloBlueBright, Android.Resource.Color.HoloGreenLight, Android.Resource.Color.HoloOrangeLight, Android.Resource.Color.HoloRedLight);
			slSwipeContainer.Refresh += SlSwipeContainer_Refresh;
		}

		protected override async void OnResume()
		{
			base.OnResume();
			await RefreshAsync();
		}

		private async void BtnAdd_Click(object sender, System.EventArgs e)
		{
			// Add item
			var item = new ManuItem { Text = etItemText.Text };
			await App.ToDoService.AddItemAsync(item);

			await RefreshAsync();
		}

		async void SlSwipeContainer_Refresh(object sender, EventArgs e)
		{
			await RefreshAsync();
			(sender as SwipeRefreshLayout).Refreshing = false;
		}

		private async Task RefreshAsync()
		{
			var allItems = await App.ToDoService.GetAllItemsAsync();
			lvItems.Adapter = new ManuItemAdapter(this, allItems.ToArray());
		}
	}
}