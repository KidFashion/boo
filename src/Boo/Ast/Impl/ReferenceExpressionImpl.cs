using System;

namespace Boo.Ast.Impl
{
	[Serializable]
	public abstract class ReferenceExpressionImpl : Expression
	{
		protected string _name;
		
		protected ReferenceExpressionImpl()
		{
 		}
		
		protected ReferenceExpressionImpl(string name)
		{
 			Name = name;
		}
		
		protected ReferenceExpressionImpl(antlr.Token token, string name) : base(token)
		{
 			Name = name;
		}
		
		internal ReferenceExpressionImpl(antlr.Token token) : base(token)
		{
 		}
		
		internal ReferenceExpressionImpl(Node lexicalInfoProvider) : base(lexicalInfoProvider)
		{
 		}
		
		public override NodeType NodeType
		{
			get
			{
				return NodeType.ReferenceExpression;
			}
		}
		public string Name
		{
			get
			{
				return _name;
			}
			
			set
			{
				_name = value;
			}
		}
		public override void Switch(IAstTransformer transformer, out Node resultingNode)
		{
			Expression resultingTypedNode;
			transformer.OnReferenceExpression((ReferenceExpression)this, out resultingTypedNode);
			resultingNode = resultingTypedNode;
		}
	}
}
