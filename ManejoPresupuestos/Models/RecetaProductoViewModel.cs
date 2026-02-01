using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{
  public class RecetaProductoViewModel
    {
        public int RecetaId { get; set; }
        public string Nombre { get; set; }

        // legacy
        public string TiempoImpresion { get; set; }

        // nuevos
        public int TiempoImpresionMin { get; set; }
        public int TiempoPostMin { get; set; }

        public int ProductoId { get; set; }
        // lo que ya tengas...
    }
}
