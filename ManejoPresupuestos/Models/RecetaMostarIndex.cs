namespace ManejoPresupuestos.Models
{
    public class RecetaMostarIndex
    {
        public int RecetaId { get; set; }
        public string Nombre { get; set; }

        public int ProductoId { get; set; }
        public string TiempoImpresion { get; set; }

        public string ProductoNombre { get; set; }
        public int ProductoCategoriaId { get; set; }

        public string ProductoCategoria { get; set; }
        public string ProductoSKU { get; set; }
    }
}
