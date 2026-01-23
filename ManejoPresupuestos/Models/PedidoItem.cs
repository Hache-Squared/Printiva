namespace ManejoPresupuestos.Models
{
    public class PedidoItem
    {
        public int PedidoItemId { get; set; }
        public int PedidoId { get; set; }
        public int ProductoId { get; set; }
        public string ProductoNombre { get; set; }
        public int Cantidad { get; set; }
        public decimal? PrecioUnitarioEstimado { get; set; }
        public string Notas { get; set; }
    }
}
