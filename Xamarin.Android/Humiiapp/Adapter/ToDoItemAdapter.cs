using System;
using Android.App;
using Android.Widget;

namespace Humiiapp
{
	public class ManuItemAdapter : BaseAdapter
	{
		Activity context;
		ManuItem[] items;

		public ManuItemAdapter(Activity context, ManuItem[] items) : base()
		{
			this.context = context;
			this.items = items;
		}

		public override Java.Lang.Object GetItem(int position)
		{
			return null;
		}

		public override long GetItemId(int position)
		{
			return position;
		}

		public override Android.Views.View GetView(int position, Android.Views.View convertView, Android.Views.ViewGroup parent)
		{
			var view = convertView ?? context.LayoutInflater.Inflate(Android.Resource.Layout.SimpleListItem1, null);
			var item = items[position];

			view.FindViewById<TextView>(Android.Resource.Id.Text1).Text = item.Text;

			if (item.Completed)
				view.Alpha = (float)0.5;

			view.Click += async delegate
			{
				item.Completed = !item.Completed;
				await App.ToDoService.UpdateItemAsync(item);
			};

			return view;
		}

		public override int Count
		{
			get
			{
				return items.Length;
			}
		}
	}
}

