using System;

namespace Boo.Ast.Impl
{
	[Serializable]
	public abstract class FieldImpl : TypeMember
	{
		protected TypeReference _type;
		
		protected FieldImpl()
		{
 		}
		
		protected FieldImpl(TypeReference type)
		{
 			Type = type;
		}
		
		protected FieldImpl(antlr.Token token, TypeReference type) : base(token)
		{
 			Type = type;
		}
		
		internal FieldImpl(antlr.Token token) : base(token)
		{
 		}
		
		internal FieldImpl(Node lexicalInfoProvider) : base(lexicalInfoProvider)
		{
 		}
		
		public override NodeType NodeType
		{
			get
			{
				return NodeType.Field;
			}
		}
		public TypeReference Type
		{
			get
			{
				return _type;
			}
			
			set
			{
				_type = value;
				if (null != _type)
				{
					_type.InitializeParent(this);
				}
			}
		}
		public override void Switch(IAstTransformer transformer, out Node resultingNode)
		{
			Field resultingTypedNode;
			transformer.OnField((Field)this, out resultingTypedNode);
			resultingNode = resultingTypedNode;
		}
	}
}
