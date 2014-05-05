package away3d.core.sort
{
	import away3d.arcane;
	import away3d.core.pool.IRenderable;
	import away3d.core.traverse.EntityCollector;
	
	use namespace arcane;
	
	/**
	 * RenderableSorter sorts the potentially visible IRenderable objects collected by EntityCollector for optimal
	 * rendering performance. Objects are sorted first by material, then by distance to the camera. Opaque objects
	 * are sorted front to back, while objects that require blending are sorted back to front, to ensure correct
	 * blending.
	 */
	public class RenderableMergeSort implements IEntitySorter
	{
		/**
		 * Creates a RenderableSorter objects
		 */
		public function RenderableMergeSort()
		{
		}

		public function sortBlendedRenderables(head:IRenderable):IRenderable
		{
			var headB:IRenderable;
			var fast:IRenderable, slow:IRenderable;
			
			if (!head || !head.next)
				return head;
			
			// split in two sublists
			slow = head;
			fast = head.next;
			
			while (fast) {
				fast = fast.next;
				if (fast) {
					slow = slow.next;
					fast = fast.next;
				}
			}
			
			headB = slow.next;
			slow.next = null;
			
			// recurse
			head = sortBlendedRenderables(head);
			headB = sortBlendedRenderables(headB);
			
			// merge sublists while respecting order
			var result:IRenderable;
			var curr:IRenderable;
			var l:IRenderable;
			
			if (!head)
				return headB;
			if (!headB)
				return head;
			
			while (head && headB && head != null && headB != null) {
				if (head.zIndex < headB.zIndex) {
					l = head;
					head = head.next;
				} else {
					l = headB;
					headB = headB.next;
				}
				
				if (!result)
					result = l;
				else
					curr.next = l;
				
				curr = l;
			}
			
			if (head)
				curr.next = head;
			else if (headB)
				curr.next = headB;
			
			return result;
		}
		
		public function sortOpaqueRenderables(head:IRenderable):IRenderable
		{
			var headB:IRenderable;
			var fast:IRenderable, slow:IRenderable;
			
			if (!head || !head.next)
				return head;
			
			// split in two sublists
			slow = head;
			fast = head.next;
			
			while (fast) {
				fast = fast.next;
				if (fast) {
					slow = slow.next;
					fast = fast.next;
				}
			}
			
			headB = slow.next;
			slow.next = null;
			
			// recurse
			head = sortOpaqueRenderables(head);
			headB = sortOpaqueRenderables(headB);
			
			// merge sublists while respecting order
			var result:IRenderable;
			var curr:IRenderable;
			var l:IRenderable;
			var cmp:int;
			
			if (!head)
				return headB;
			if (!headB)
				return head;
			
			while (head && headB && head != null && headB != null) {
				
				// first sort per render order id (reduces program3D switches),
				// then on material id (reduces setting props),
				// then on zIndex (reduces overdraw)
				var aid:uint = head.renderOrderId;
				var bid:uint = headB.renderOrderId;
				
				if (aid == bid) {
					var ma:uint = head.materialId;
					var mb:uint = headB.materialId;
					
					if (ma == mb) {
						if (head.zIndex < headB.zIndex)
							cmp = 1;
						else
							cmp = -1;
					} else if (ma > mb)
						cmp = 1;
					else
						cmp = -1;
				} else if (aid > bid)
					cmp = 1;
				else
					cmp = -1;
				
				if (cmp < 0) {
					l = head;
					head = head.next;
				} else {
					l = headB;
					headB = headB.next;
				}
				
				if (!result) {
					result = l;
					curr = l;
				} else {
					curr.next = l;
					curr = l;
				}
			}
			
			if (head)
				curr.next = head;
			else if (headB)
				curr.next = headB;
			
			return result;
		}
	}
}
